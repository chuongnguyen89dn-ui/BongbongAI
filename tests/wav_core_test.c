#include "../overlay/BBPCMCore.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned checks;
#define ASSERT(x) do {++checks;if (!(x)) {fprintf(stderr,"FAIL %s:%d %s\n",__FILE__,__LINE__,#x);exit(1);}} while(0)

static uint32_t le32(const unsigned char *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1]<<8) | ((uint32_t)p[2]<<16) | ((uint32_t)p[3]<<24);
}
int main(void) {
    const size_t length=48000*3; // three one-second segments, merged once
    uint8_t *pcm=malloc(length), *wav=malloc(length+44);
    ASSERT(pcm && wav);
    for (size_t i=0;i<length;++i) pcm[i]=(uint8_t)((i*17+1)%251);
    size_t produced=900;
    ASSERT(bb_pcm_to_wav(pcm,length,wav,length+44,&produced)==1);
    ASSERT(produced==length+44);
    ASSERT(!memcmp(wav,"RIFF",4));
    ASSERT(le32(wav+4)==length+36);
    ASSERT(!memcmp(wav+8,"WAVEfmt ",8));
    ASSERT(le32(wav+16)==16);
    ASSERT(wav[20]==1 && wav[21]==0);
    ASSERT(wav[22]==1 && wav[23]==0);
    ASSERT(le32(wav+24)==24000);
    ASSERT(le32(wav+28)==48000);
    ASSERT(wav[32]==2 && wav[34]==16);
    ASSERT(!memcmp(wav+36,"data",4));
    ASSERT(le32(wav+40)==length);
    ASSERT(!memcmp(wav+44,pcm,length));
    produced=900;
    ASSERT(!bb_pcm_to_wav(pcm,2401,wav,length+44,&produced));
    ASSERT(produced==0);
    ASSERT(!bb_pcm_to_wav(pcm,0,wav,length+44,&produced));
    ASSERT(!bb_pcm_to_wav(pcm,length,wav,length+43,&produced));
    ASSERT(!bb_pcm_to_wav(NULL,length,wav,length+44,&produced));
    ASSERT(!bb_pcm_to_wav(pcm,length,NULL,length+44,&produced));
    ASSERT(!bb_pcm_to_wav(pcm,length,wav,length+44,NULL));
    ASSERT(!bb_pcm_to_wav(pcm,17*1024*1024,wav,length+44,&produced));
    free(pcm);free(wav);
    printf("PASS %u portable WAV boundary checks (no iOS SDK needed)\n",checks);
    return 0;
}
