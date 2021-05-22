#!/bin/bash

echo "Growing partition"

if [[ -b /dev/vda3 ]]; then
  sudo growpart /dev/vda 3
  sudo resize2fs /dev/vda3
elif [[ -b /dev/sda3 ]]; then
  sudo growpart /dev/sda 3
  sudo resize2fs /dev/sda3
fi
