/* Production readback functions with explicit mapped-memory/COM fixtures.
 * No GPU, selection draw or desktop presentation is claimed by these tests. */
#include "cjgui_windows_renderer.c"
#include <float.h>

static int failures;
static void check(const char *name, int pass) {
    printf("FRAME_READBACK %s pass=%d\n", name, !!pass);
    failures += !pass;
}
static uint64_t legacy_hash(const uint8_t *data, size_t pitch, uint32_t top,
    const uint32_t box[4]) {
    uint64_t hash=1469598103934665603ull;
    for(uint32_t y=box[1]-top;y<box[3]-top;y+=4u)
        for(uint32_t x=box[0];x<box[2];x+=4u) {
            uint32_t pixel;memcpy(&pixel,data+(size_t)y*pitch+(size_t)x*4u,4);
            pixel&=0x00ffffffu;
            hash=windows_fnv1a64(hash,&pixel,4);
        }
    return hash;
}
static void bounds_cases(void) {
    struct Case {const char *name;double l,t,r,b;int status;uint32_t box[4];} cases[]={
        {"whole_left",-100,30,-90,60,0,{0}},
        {"whole_above",10,-100,40,-90,0,{0}},
        {"whole_right",120,30,130,60,0,{0}},
        {"whole_below",10,120,40,130,0,{0}},
        {"partial",-5,10,25,60,1,{0,20,25,60}},
        {"fractional_truncation",10.75,30.875,50.125,50.625,1,{10,30,50,50}},
        {"right_bottom_clip",90.5,90.5,120,120,1,{90,90,100,100}},
        {"touch_left",-10,30,0,60,0,{0}},
        {"touch_top",10,0,40,20,0,{0}},
        {"touch_right",100,30,110,60,0,{0}},
        {"touch_bottom",10,100,40,110,0,{0}},
        {"zero",10,30,10,60,0,{0}},
        {"subpixel_empty",10.1,30.1,10.9,30.9,0,{0}},
        {"small_valid_box",10,30,12,32,1,{10,30,12,32}},
        {"reversed",40,30,10,60,-1,{0}},
        {"nan",NAN,30,40,60,-1,{0}},
        {"positive_infinity",10,30,INFINITY,60,-1,{0}},
        {"negative_infinity",-INFINITY,30,40,60,-1,{0}},
        {"large_finite_clip",-DBL_MAX,-DBL_MAX,DBL_MAX,DBL_MAX,1,{0,20,100,100}},
        {"arithmetic_overflow",10,30,DBL_MAX*2.0,60,-1,{0}}
    };
    for(size_t i=0;i<sizeof(cases)/sizeof(*cases);++i) {
        uint32_t box[4]={0};struct Case *c=&cases[i];
        int status=windows_frame_sample_bounds(c->l,c->t,c->r,c->b,100,20,100,box);
        int pass=status==c->status;
        if(status==1 && c->status==1)pass=pass && !memcmp(box,c->box,sizeof(box));
        check(c->name,pass);
    }
    uint32_t box[4];
    check("invalid_band",windows_frame_sample_bounds(0,0,10,10,100,30,20,box)==-1);
    check("mapped_padding",windows_frame_mapped_readable((void*)1,131,32,18));
    check("mapped_small_pitch",!windows_frame_mapped_readable((void*)1,127,32,18));
    check("mapped_null",!windows_frame_mapped_readable(NULL,128,32,18));
    check("mapped_width_overflow",!windows_frame_mapped_readable((void*)1,SIZE_MAX,SIZE_MAX,2));
    check("mapped_row_overflow",!windows_frame_mapped_readable((void*)1,SIZE_MAX/2,32,4));
}

typedef struct TextureFixture {ID3D11Texture2D iface;D3D11_TEXTURE2D_DESC desc;unsigned releases;} TextureFixture;
static TextureFixture back,staging;
static unsigned bufferGets,maps,unmaps,copies;
static HRESULT mapResult=S_OK;
static D3D11_MAPPED_SUBRESOURCE mappedFixture;
static void STDMETHODCALLTYPE texture_desc(ID3D11Texture2D *raw,D3D11_TEXTURE2D_DESC *out) {
    *out=((TextureFixture*)raw)->desc;
}
static ULONG STDMETHODCALLTYPE texture_release(ID3D11Texture2D *raw) {
    ++((TextureFixture*)raw)->releases;return 1;
}
static HRESULT STDMETHODCALLTYPE swap_buffer(IDXGISwapChain *raw,UINT index,REFIID iid,void **out) {
    (void)raw;(void)index;(void)iid;++bufferGets;*out=&back.iface;return S_OK;
}
static void STDMETHODCALLTYPE context_copy(ID3D11DeviceContext *raw,ID3D11Resource *dst,UINT sub,
    UINT x,UINT y,UINT z,ID3D11Resource *src,UINT srcSub,const D3D11_BOX *box) {
    (void)raw;(void)dst;(void)sub;(void)x;(void)y;(void)z;(void)src;(void)srcSub;(void)box;++copies;
}
static HRESULT STDMETHODCALLTYPE context_map(ID3D11DeviceContext *raw,ID3D11Resource *resource,
    UINT sub,D3D11_MAP mode,UINT flags,D3D11_MAPPED_SUBRESOURCE *out) {
    (void)raw;(void)resource;(void)sub;(void)mode;(void)flags;++maps;*out=mappedFixture;return mapResult;
}
static void STDMETHODCALLTYPE context_unmap(ID3D11DeviceContext *raw,ID3D11Resource *resource,UINT sub) {
    (void)raw;(void)resource;(void)sub;++unmaps;
}
static ID3D11Texture2DVtbl textureVtable={.Release=texture_release,.GetDesc=texture_desc};
static IDXGISwapChainVtbl swapVtable={.GetBuffer=swap_buffer};
static ID3D11DeviceContextVtbl contextVtable={.Map=context_map,.Unmap=context_unmap,.CopySubresourceRegion=context_copy};
static IDXGISwapChain swap={&swapVtable};
static ID3D11DeviceContext context={&contextVtable};

static void reset_fixture(CjguiWindowsRendererSession *s,void *pixels,UINT pitch) {
    memset(s,0,sizeof(*s));memset(&back,0,sizeof(back));memset(&staging,0,sizeof(staging));
    back.iface.lpVtbl=staging.iface.lpVtbl=&textureVtable;
    back.desc.Width=32;back.desc.Height=30;back.desc.Format=DXGI_FORMAT_B8G8R8A8_UNORM;
    staging.desc=back.desc;staging.desc.Height=18;
    s->swapChain=&swap;s->device=(ID3D11Device*)(uintptr_t)1;s->context=&context;
    s->receiptStaging=&staging.iface;s->receiptStagingWidth=32;s->receiptStagingHeight=18;
    s->dpi=96;s->frameIndex=12;
    mappedFixture.pData=pixels;mappedFixture.RowPitch=pitch;mappedFixture.DepthPitch=1; /* Not an allocation bound. */
    bufferGets=maps=unmaps=copies=0;mapResult=S_OK;
    s->frameEvidence.valid=1;s->frameEvidence.nodeHashCount=7;s->frameEvidence.hash=999;
}
static void map_cases(void) {
    SYSTEM_INFO info;GetSystemInfo(&info);size_t page=info.dwPageSize;
    uint8_t *allocation=VirtualAlloc(NULL,page*3,MEM_COMMIT|MEM_RESERVE,PAGE_READWRITE);
    check("guard_allocation",allocation!=NULL);if(!allocation)return;
    DWORD protection;VirtualProtect(allocation,page,PAGE_NOACCESS,&protection);
    VirtualProtect(allocation+page*2,page,PAGE_NOACCESS,&protection);
    const UINT pitch=131;uint8_t *pixels=allocation+page*2-(size_t)pitch*18;
    for(size_t i=0;i<(size_t)pitch*18;++i)pixels[i]=(uint8_t)(i*17u+3u);
    CjguiWindowsRendererSession *s=calloc(1,sizeof(*s));check("session_allocation",s!=NULL);if(!s){VirtualFree(allocation,0,MEM_RELEASE);return;}
    CjguiWindowsSceneNode node={0};node.node.nodeId=1001;node.textLayout=(void*)1;
    node.node.x=4;node.node.y=10;node.node.width=12;node.node.height=12;
    CjguiWindowsScene scene={0};scene.nodes=&node;scene.count=1;scene.version=11;
    _putenv_s("PHAROS_WINDOWS_FRAME_RECEIPT","1");_putenv_s("PHAROS_WINDOWS_SELECTION_ROI_DIR","");
    reset_fixture(s,pixels,pitch);windows_freeze_frame_evidence(s,&scene);
    uint32_t box[]={4,10,16,22};
    check("legal_original_hash_padding",s->frameEvidence.nodeHashCount==1 &&
        s->frameEvidence.nodeHash[0]==legacy_hash(pixels,pitch,6,box));
    char directory[MAX_PATH],temp[MAX_PATH],path[MAX_PATH];
    GetTempPathA(MAX_PATH,temp);GetTempFileNameA(temp,"cjr",0,directory);DeleteFileA(directory);
    int made=CreateDirectoryA(directory,NULL)!=0;
    int bmpOk=made && windows_roi_bmp(s,directory,"roi.bmp",&mappedFixture,6,box,1);
    snprintf(path,sizeof(path),"%s/roi.bmp",directory);FILE *bmp=bmpOk?fopen(path,"rb"):NULL;
    uint8_t rowBytes[48];int same=bmp!=NULL;
    if(bmp){same=fseek(bmp,54,SEEK_SET)==0;
        for(size_t y=10;y<22 && same;++y) same=fread(rowBytes,1,48,bmp)==48 &&
            !memcmp(rowBytes,pixels+(y-6)*pitch+16,48);
        same=same && fgetc(bmp)==EOF;fclose(bmp);}
    check("lossless_roi_exact_rows_with_padding",same);DeleteFileA(path);
    CjguiWindowsSelectionDrawRow drawRow={0};char assetName[128];
    node.node.fontSize=18;node.node.fontWeight=400;
    int assetOk=made && windows_roi_asset(s,&node,&drawRow,directory,assetName);
    char assetPath[MAX_PATH],assetBody[2048]={0};
    snprintf(assetPath,sizeof(assetPath),"%s/%s",directory,assetName);
    FILE *asset=assetOk?fopen(assetPath,"rb"):NULL;
    if(asset){fread(assetBody,1,sizeof(assetBody)-1,asset);fclose(asset);}
    check("immutable_layout_dimensions_exact",asset && strstr(assetBody,"\"width\":12,\"height\":12")!=NULL);
    DeleteFileA(assetPath);snprintf(assetPath,sizeof(assetPath),"%s/%s.utf8",directory,assetName);DeleteFileA(assetPath);
    snprintf(assetPath,sizeof(assetPath),"%s/%s.runs",directory,assetName);DeleteFileA(assetPath);
    if(made)RemoveDirectoryA(directory);
    node.node.x=-100;node.node.width=10;node.node.height=10;
    reset_fixture(s,pixels,pitch);windows_freeze_frame_evidence(s,&scene);
    check("actual_scanner_whole_left_guard",s->frameEvidence.valid==1 && !s->frameEvidence.nodeHashCount);
    check("success_unmap_release_once",maps==1 && unmaps==1 && back.releases==1 && staging.releases==0);
    node.node.x=4;node.node.y=-100;node.node.width=12;node.node.height=10;
    reset_fixture(s,pixels,pitch);windows_freeze_frame_evidence(s,&scene);
    check("actual_scanner_whole_above_guard",s->frameEvidence.valid==1 && !s->frameEvidence.nodeHashCount);
    node.node.y=10;node.node.height=12;
    reset_fixture(s,pixels,127);windows_freeze_frame_evidence(s,&scene);
    check("small_pitch_before_any_scan",s->frameEvidence.valid==3 && s->frameEvidence.roiStatus==5 &&
        s->frameEvidence.nodeHashCount==0 && s->frameEvidence.hash==0 && maps==1 && unmaps==1 && back.releases==1);
    reset_fixture(s,NULL,pitch);windows_freeze_frame_evidence(s,&scene);
    check("null_map_before_any_scan",s->frameEvidence.valid==3 && unmaps==1 && back.releases==1);
    reset_fixture(s,pixels,pitch);mapResult=E_FAIL;windows_freeze_frame_evidence(s,&scene);
    check("failed_map_no_unmap",s->frameEvidence.valid==0 && maps==1 && !unmaps && back.releases==1);
    reset_fixture(s,pixels,pitch);staging.desc.Height=17;windows_freeze_frame_evidence(s,&scene);
    check("staging_extent_before_copy_map",s->frameEvidence.valid==3 && s->frameEvidence.roiStatus==6 &&
        !copies && !maps && !unmaps && back.releases==1);
    reset_fixture(s,pixels,pitch);back.desc.Format=DXGI_FORMAT_R16_FLOAT;windows_freeze_frame_evidence(s,&scene);
    check("unsupported_format_release",s->frameEvidence.valid==2 && !maps && !unmaps && back.releases==1);
    reset_fixture(s,pixels,pitch);windows_freeze_frame_evidence(s,&scene);
    check("success_after_error",s->frameEvidence.valid==1 && maps==1 && unmaps==1 && back.releases==1);
    _putenv_s("PHAROS_WINDOWS_FRAME_RECEIPT","");reset_fixture(s,pixels,pitch);
    windows_freeze_frame_evidence(s,&scene);
    check("default_off_no_readback",s->frameEvidence.valid==0 && !bufferGets && !maps && !unmaps && !copies && !back.releases);
    /* Direct scanner domain excludes a deliberately different rail. */
    uint64_t hash1=0,hash2=0;uint32_t bounds[4];
    int a=windows_frame_sample_node_hash(pixels,pitch,24,6,24,4,10,32,22,&hash1,bounds);
    for(size_t y=0;y<18;++y)memset(pixels+y*pitch+24*4,0xff,8*4);
    int b=windows_frame_sample_node_hash(pixels,pitch,24,6,24,4,10,32,22,&hash2,bounds);
    check("document_hash_excludes_rail",a==1 && b==1 && hash1==hash2 && bounds[2]==24);
    free(s);VirtualFree(allocation,0,MEM_RELEASE);
}
int main(void) {
    SetErrorMode(SEM_FAILCRITICALERRORS|SEM_NOGPFAULTERRORBOX);
    setvbuf(stdout,NULL,_IONBF,0);bounds_cases();map_cases();
    printf("FRAME_READBACK_RESULT failures=%d\n",failures);return failures?1:0;
}
