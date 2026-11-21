#ifndef BB_PCM_CORE_H
#define BB_PCM_CORE_H

#include <stddef.h>
#include <stdint.h>

/* Portable 16-bit LE mono PCM -> 24 kHz RIFF/WAV. Returns 1 only for a complete output. */
int bb_pcm_to_wav(const uint8_t *pcm, size_t pcm_bytes,
                  uint8_t *out, size_t out_capacity, size_t *out_size);

#endif
