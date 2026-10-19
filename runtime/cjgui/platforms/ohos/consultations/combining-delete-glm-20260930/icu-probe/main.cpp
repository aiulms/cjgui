#include <unicode/ubrk.h>
#include <unicode/ustring.h>
#include <unicode/uvernum.h>
#include <cstdio>
#include <vector>
#include <string>
int main() {
 const char* inputs[]={u8"e\u0301",u8"👨‍👩‍👧‍👦",u8"👍🏽",u8"🇨🇳",u8"中",u8"a\r\nb"};
 printf("ICU_HEADER=%s\n", U_ICU_VERSION);
 for (const char* input:inputs) {
  std::string bytes(input); UErrorCode error=U_ZERO_ERROR; int32_t size=0;
  u_strFromUTF8(nullptr,0,&size,bytes.data(),bytes.size(),&error);
  if(error!=U_BUFFER_OVERFLOW_ERROR && U_FAILURE(error)) return 1;
  error=U_ZERO_ERROR; std::vector<UChar> text(size+1);
  u_strFromUTF8(text.data(),text.size(),&size,bytes.data(),bytes.size(),&error);
  if(U_FAILURE(error)) return 2;
  auto* bi=ubrk_open(UBRK_CHARACTER,"root",text.data(),size,&error);
  if(U_FAILURE(error)||!bi) { printf("OPEN_ERROR=%d\n",error);return 3; }
  printf("UTF8=");for(unsigned char ch:bytes) printf("%02X",ch);printf(" UTF16=%d BOUNDARIES=",size);
  for(int32_t pos=ubrk_first(bi);pos!=UBRK_DONE;pos=ubrk_next(bi)) printf("%d,",pos);
  printf("\n"); ubrk_close(bi);
 }
 return 0;
}
