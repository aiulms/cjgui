import { socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import entryNapi from 'libentry.so';

const MAX_LINE_BYTES = 64 * 1024;

@Entry
@Component
struct Index {
  @State simResult: string = 'EXT-SIM idle';
  private pumpTimerId: number = -1;

  build() {
    Column() {
      XComponent({ id: 'cards_surface', type: XComponentType.SURFACE, libraryname: 'entry' })
        .onLoad(() => {
          // The native module registered its surface/touch callbacks during
          // library load; this timer only submits frames when the state
          // changed (idle produces no new submission).
          this.pumpTimerId = setInterval(() => {
            entryNapi.pumpFrame();
          }, 33);
        })
        .onDestroy(() => {
          if (this.pumpTimerId >= 0) {
            clearInterval(this.pumpTimerId);
            this.pumpTimerId = -1;
          }
          entryNapi.shutdown();
        })
        .width('100%')
        .layoutWeight(1)

      Button('EXT-SIM')
        .onClick(() => {
          this.runExternalSimulation();
        })
        .margin(12)

      Text(this.simResult)
        .fontSize(12)
        .margin({ bottom: 16 })
        .maxLines(4)
    }
    .height('100%')
    .width('100%')
  }

  // In-app external simulation: a plain loopback TCP client (the same socket
  // capability an ordinary sandboxed app has — no hdc forwarding involved).
  // Framing contract: handlers are registered before connect, requests are
  // sent once the connect promise resolves, responses are accumulated until
  // '\n', and every step propagates errors instead of swallowing them.
  private runExternalSimulation(): void {
    this.simResult = 'EXT-SIM connecting...';
    const tcpSocket = socket.constructTCPSocketInstance();
    const decoder = util.TextDecoder.create('utf-8');
    let buffer = '';
    const responses: string[] = [];
    let stateVersion = 0;
    let capability = '';

    const decode = (data: ArrayBuffer): string => {
      return decoder.decodeToString(new Uint8Array(data));
    };
    const fail = (message: string) => {
      this.simResult = 'sim failed: ' + message;
      tcpSocket.close().catch(() => {});
    };
    const send = (line: string): boolean => {
      if ((line + '\n').length > MAX_LINE_BYTES) {
        fail('frame too large');
        return false;
      }
      tcpSocket.send({ data: line + '\n' }).catch(() => {
        fail('send failed: ' + line);
      });
      return true;
    };
    const handleLine = (line: string): boolean => {
      const text = line.trim();
      if (text.startsWith('OK smoke-protocol/1 CAP ')) {
        capability = text.substring('OK smoke-protocol/1 CAP '.length);
        send(`STATE`);
        return true;
      }
      if (text.startsWith('V ')) {
        stateVersion = Number(text.split(' ')[1]);
        // Wrong token, stale version, then the authorized operation. The
        // authorized TOGGLE 2 bumps the version to 1.
        send(`OP wrongtoken ${stateVersion} MOVE 1 200 200`);
        send(`OP ${capability} ${stateVersion + 5} MOVE 1 480 240`);
        send(`OP ${capability} ${stateVersion} TOGGLE 2`);
        return true;
      }
      responses.push(text);
      if (responses.length >= 3) {
        const unauthorized = responses[0] === 'ERR unauthorized';
        const stale = responses[1] === 'ERR stale_version';
        const applied = responses[2] === 'OK V1';
        this.simResult = 'sim: ' + responses.join(' | ');
        tcpSocket.close().catch(() => {});
        if (!unauthorized || !stale || !applied) {
          fail(`unexpected responses: ${responses.join(' | ')}`);
        }
        return false;
      }
      return true;
    };

    tcpSocket.on('message', (value: socket.SocketMessageInfo) => {
      buffer += decode(value.message);
      if (buffer.length > MAX_LINE_BYTES) {
        fail('frame too large');
        return;
      }
      let newline = buffer.indexOf('\n');
      while (newline >= 0) {
        const line = buffer.substring(0, newline);
        buffer = buffer.substring(newline + 1);
        if (!handleLine(line)) return;
        newline = buffer.indexOf('\n');
      }
    });
    tcpSocket.on('error', (error: Error) => {
      fail('socket error: ' + error.message);
    });

    const localAddress: socket.NetAddress = { address: '127.0.0.1', port: 0, family: 1 };
    tcpSocket.bind(localAddress).then(() => {
      const remoteAddress: socket.NetAddress = { address: '127.0.0.1', port: 7856, family: 1 };
      return tcpSocket.connect({ address: remoteAddress, timeout: 3000 });
    }).then(() => {
      // The connect promise resolved: send the handshake directly instead of
      // relying on a connect event that may already have been missed.
      send('HELLO');
    }).catch((error: Error) => {
      fail('connect/bind failed: ' + error.message);
    });
  }
}
