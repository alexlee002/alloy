//
//  RC4.m
//  patchwork
//
//  Created by Alex Lee on 3/22/16.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "RC4.h"
#import "UtilitiesHeader.h"

const char base[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

const char rc4key[] = "7FED2719FC7E4D5602FB1D9D11AFA01B";

typedef struct rc4_key {
    unsigned char state[256];
    unsigned char x;
    unsigned char y;
} rc4_key;

struct rc4_state {
    u_char perm[256];
    u_char index1;
    u_char index2;
};


//static FORCE_INLINE char find_pos(char ch) {
//    char *ptr = (char *)strrchr(base, ch);  // the last position (the only) in base[]
//    return (ptr - base);
//}

static FORCE_INLINE void swap_byte(unsigned char *x, unsigned char *y) {
    *x = *x ^ *y;
    *y = *x ^ *y;
    *x = *x ^ *y;
}

static FORCE_INLINE void prepare_key(unsigned char *const key_data_ptr, int key_data_len, rc4_key *key) {
    unsigned char index1;
    unsigned char index2;
    unsigned char *state;
    short counter;
    state = &key->state[0];
    for (counter = 0; counter < 256; counter++) state[counter] = counter;
    key->x = 0;
    key->y = 0;
    index1 = 0;
    index2 = 0;
    for (counter = 0; counter < 256; counter++) {
        index2 = (key_data_ptr[index1] + state[counter] + index2) % 256;
        swap_byte(&state[counter], &state[index2]);
        index1 = (index1 + 1) % key_data_len;
    }
}

static FORCE_INLINE void rc4(unsigned char *buffer_ptr, int buffer_len, rc4_key *key) {
    //  unsigned char t;
    unsigned char x;
    unsigned char y;
    unsigned char *state;
    unsigned char xorIndex;
    short counter;
    x = key->x;
    y = key->y;
    state = &key->state[0];
    for (counter = 0; counter < buffer_len; counter++) {
        x = (x + 1) % 256;
        y = (state[x] + y) % 256;
        swap_byte(&state[x], &state[y]);
        xorIndex = (state[x] + state[y]) % 256;
        buffer_ptr[counter] ^= state[xorIndex];
    }
    key->x = x;
    key->y = y;
}

//static FORCE_INLINE void rc4encode(char *rc4input, int rc4len) {
//    struct rc4_key s;
//    prepare_key((unsigned char *const)rc4key, 32, &s);
//    rc4((unsigned char *)rc4input, rc4len, &s);
//}

static FORCE_INLINE void swap_bytes(u_char *a, u_char *b) {
    u_char temp;
    
    temp = *a;
    *a = *b;
    *b = temp;
}

/*
 * Initialize an RC4 state buffer using the supplied key,
 * which can have arbitrary length.
 */
static FORCE_INLINE void rc4_init(struct rc4_state *const state, const u_char *key, int keylen) {
    u_char j;
    int i, k;
    
    /* Initialize state with identity permutation */
    for (i = 0; i < 256; i++) state->perm[i] = (u_char)i;
    state->index1 = 0;
    state->index2 = 0;
    
    /* Randomize the permutation using key data */
    for (j = i = k = 0; i < 256; i++) {
        j += state->perm[i] + key[k];
        swap_bytes(&state->perm[i], &state->perm[j]);
        if (++k >= keylen) k = 0;
    }
}

/*
 * Encrypt some data using the supplied RC4 state buffer.
 * The input and output buffers may be the same buffer.
 * Since RC4 is a stream cypher, this function is used
 * for both encryption and decryption.
 */
static FORCE_INLINE void rc4_crypt(struct rc4_state *const state, const u_char *inbuf, u_char *outbuf, int buflen) {
    int i;
    u_char j;
    
    for (i = 0; i < buflen; i++) {
        /* Update modification indicies */
        state->index1++;
        state->index2 += state->perm[state->index1];
        
        /* Modify permutation */
        swap_bytes(&state->perm[state->index1], &state->perm[state->index2]);
        
        /* Encrypt/decrypt next byte */
        j = state->perm[state->index1] + state->perm[state->index2];
        outbuf[i] = inbuf[i] ^ state->perm[j];
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSData category

@implementation NSData (ALExtension_RC4)

- (NSData *)dataByRC4EncryptingWithKey:(NSString *)encryptionKey {
    int lenPim = (int)self.length;
    char *strRc4 = (char *)malloc(lenPim);
    const char *pDest = [self bytes];
    memset(strRc4, 0, lenPim);
    memcpy(strRc4, pDest, lenPim);
    u_char *strOut = (u_char *)malloc(lenPim);
    memset(strOut, 0, lenPim);
    
    struct rc4_state rc4s;
    const char *rc4key = [encryptionKey UTF8String];
    rc4_init(&rc4s, (const u_char *)rc4key, (int)encryptionKey.length);
    rc4_crypt(&rc4s, (u_char *)strRc4, strOut, lenPim);
    
    NSData *logRC4 = [NSData dataWithBytes:strOut length:lenPim];
    free(strRc4);
    free(strOut);
    
    return logRC4;
}

@end

