#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=X00TD
VENDOR=asus

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"
                shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in

        # Fix jar path
        product/etc/permissions/qti_fingerprint_interface.xml)
        [ "$2" = "" ] && return 0
        sed -i 's|/system/framework/|/system/product/framework/|g' "${2}"
        ;;

        # remove android.hidl.base dependency
        vendor/lib/hw/camera.sdm660.so)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --remove-needed "android.hidl.base@1.0.so" "${2}"
        ;;

        lib64/libwfdnative.so | lib/libwfdnative.so | lib/libwfdservice.so | lib/libwfdcommonutils.so | lib/libwfdmmsrc.so | lib/libwfdmmsink.so)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --add-needed "libshim_wfd.so" "${2}"
        ;;

        # Use VNDK 29 protobuf
        vendor/lib64/libwvhidl.so)
        [ "$2" = "" ] && return 0
        "${PATCHELF}" --replace-needed "libprotobuf-cpp-lite-3.9.1.so" "libprotobuf-cpp-full-3.9.1.so" "${2}"
        ;;

        # fingerprint: use libhidlbase-v32 for goodix
        vendor/lib64/libvendor.goodix.hardware.fingerprint@1.0.so | vendor/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so)
        [ "$2" = "" ] && return 0
        grep -q "libhidlbase-v32.so" "${2}" || "${PATCHELF}" --replace-needed "libhidlbase.so" "libhidlbase-v32.so" "${2}"
        ;;

        vendor/lib64/libril-qc-hal-qmi.so)
        [ "$2" = "" ] && return 0
        for v in 1.{0..2}; do
            sed -i "s|android.hardware.radio.config@${v}.so|android.hardware.radio.c_shim@${v}.so|g" "${2}"
        done
        ;;

    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
