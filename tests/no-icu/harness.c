#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unicode/ustring.h>
#define ASSERT(c,v) do{if(!(c))return v;}while(0)
#include "no_icu_code.c"
static size_t my_strlcpy(char *dest, const char *src, size_t n) {
#include "no_icu_strlcpy.c"
}
static int icu_cmp(const char*a,const char*b,int n){UChar x[4096],y[4096];int32_t l0,l1;UErrorCode e0=0,e1=0,e=0;
 u_strFromUTF8Lenient(x,4095,&l0,a,-1,&e0);u_strFromUTF8Lenient(y,4095,&l1,b,-1,&e1);x[l0]=0;y[l1]=0;
 if(n>=0){if(l0>n)l0=n;if(l1>n)l1=n;return u_strCaseCompare(x,l0,y,l1,0,&e);}
 return u_strCaseCompare(x,-1,y,-1,0,&e);}
static int sgn(int v){return (v>0)-(v<0);}
int main(int argc,char**argv){
 static char *w[20000];int n=0;char line[4096];
 while(fgets(line,sizeof line,stdin)&&n<20000){line[strcspn(line,"\n")]=0;w[n++]=strdup(line);}
 long bad=0,tot=0,badn=0,bads=0;
 for(int i=0;i<n;i++)for(int j=i;j<n&&j<i+60;j++){tot++;
   int a=sgn(icu_cmp(w[i],w[j],-1)),b=sgn(fc_utf8_casecmp(w[i],w[j],(size_t)-1));
   if(a!=b){bad++; if(bad<8)printf("cmp '%s' '%s' icu=%d ours=%d\n",w[i],w[j],a,b);}
   int nn=(i+j)%7;a=sgn(icu_cmp(w[i],w[j],nn));b=sgn(fc_utf8_casecmp(w[i],w[j],nn));if(a!=b){badn++;}
 }
 /* strlcpy: compare with ICU-like behaviour: result prefix is valid UTF-8 and <= n-1 */
 for(int i=0;i<n;i++)for(size_t k=1;k<20;k++){char d[64];size_t r=my_strlcpy(d,w[i],k);
   if(r!=strlen(w[i])||strlen(d)>k-1||strncmp(d,w[i],strlen(d)))bads++;
   size_t L=strlen(d); if(L<strlen(w[i]) && ((unsigned char)w[i][L]&0xC0)==0x80) bads++; }
 printf("pairs %ld, full mismatches %ld, n-limited mismatches %ld, strlcpy problems %ld\n",tot,bad,badn,bads);
 return 0;}
