#include "BBPCMCore.h"
#include <string.h>

#define BB_WAV_HEADER_BYTES 44u
#define BB_PCM_MAX_BYTES (16u * 1024u * 1024u)

static void write16(uint8_t *p, uint16_t n) {
    p[0]=(uint8_t)n; p[1]=(uint8_t)(n>>8);
}
static void write32(uint8_t *p, uint32_t n) {
    p[0]=(uint8_t)n; p[1]=(uint8_t)(n>>8);
    p[2]=(uint8_t)(n>>16); p[3]=(uint8_t)(n>>24);
}

int bb_pcm_to_wav(const uint8_t *pcm, size_t pcm_bytes,
                  uint8_t *out, size_t out_capacity, size_t *out_size) {
    if (out_size) *out_size=0;
    if (!pcm || !out || !out_size || pcm_bytes<2400 || (pcm_bytes&1) ||
        pcm_bytes>BB_PCM_MAX_BYTES || out_capacity<BB_WAV_HEADER_BYTES ||
        pcm_bytes>out_capacity-BB_WAV_HEADER_BYTES) return 0;
    memset(out,0,BB_WAV_HEADER_BYTES);
    memcpy(out,"RIFF",4); write32(out+4,(uint32_t)(pcm_bytes+36));
    memcpy(out+8,"WAVEfmt ",8); write32(out+16,16);
    write16(out+20,1); write16(out+22,1);
    write32(out+24,24000); write32(out+28,48000);
    write16(out+32,2); write16(out+34,16);
    memcpy(out+36,"data",4); write32(out+40,(uint32_t)pcm_bytes);
    memcpy(out+44,pcm,pcm_bytes);
    *out_size=pcm_bytes+BB_WAV_HEADER_BYTES;
    return 1;
}
