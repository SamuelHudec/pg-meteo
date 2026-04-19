#pragma once

#include "esp_rom_md5.h"

#include <cstdio>
#include <string>

inline std::string windguru_md5_hex(const std::string &input) {
  md5_context_t ctx;
  uint8_t digest[16];
  char hex[33];

  esp_rom_md5_init(&ctx);
  esp_rom_md5_update(&ctx, reinterpret_cast<const uint8_t *>(input.data()), input.size());
  esp_rom_md5_final(digest, &ctx);

  for (size_t i = 0; i < sizeof(digest); i++) {
    std::snprintf(hex + (i * 2), 3, "%02x", digest[i]);
  }
  hex[32] = '\0';

  return std::string(hex);
}
