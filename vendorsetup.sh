rm -rf kernel/asus/sdm660
git clone --depth=1 --recursive https://github.com/Tiktodz/android_kernel_asus_sdm660 kernel/asus/sdm660
rm -rf kernel/asus/sdm660/KernelSU/userspace
rm -rf kernel/asus/sdm660/KernelSU/website

rm -rf device/asus/X00TD
git clone --depth=1 https://github.com/Tiktodz/android_device_asus_X00TD -b everest device/asus/X00TD

rm -rf vendor/asus
git clone --depth=1 https://github.com/Tiktodz/android_vendor_asus_X00TD -b udc-4.19 vendor/asus

rm -rf vendor/extra
git clone --depth=1 https://github.com/Tiktodz/vendor -b everest kntl && cp -R kntl/* vendor/ && rm -rf kntl

export TZ=Asia/Jakarta
