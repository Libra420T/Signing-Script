#!/bin/bash

set -e

echo "This script will generate Android keys for signing builds."

subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'

echo "Using Subject Line:\n$subject"

read -p "Is the subject line correct? (y/n): " confirmation
if [[ $confirmation != "y" && $confirmation != "Y" ]]; then
    echo "Exiting without changes."
    exit 1
fi
clear

certs_dir="$HOME/.android-certs"
if [ -d "$certs_dir" ]; then
    read -p "Existing Android certificates found. Do you want to remove them? (y/n): " remove_confirmation
    if [[ $remove_confirmation == "y" || $remove_confirmation == "Y" ]]; then
        rm -rf "$certs_dir"
        echo "Old Android certificates removed."
    else
        echo "Exiting without changes."
        exit 1
    fi
fi

mkdir -p "$certs_dir"
echo "Press ENTER TWICE to skip password (about 10-15 enter hits total). Cannot use a password for inline signing!"

keys=(bluetooth media networkstack nfc platform releasekey sdk_sandbox shared testkey verifiedboot)
for key in "${keys[@]}"; do 
    ./development/tools/make_key "$certs_dir/$key" "$subject"
done

vendor_keys_dir="vendor/aosp-priv/keys"
mkdir -p "$vendor_keys_dir"
mv "$certs_dir" "$vendor_keys_dir"

echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := $vendor_keys_dir/releasekey" > "$vendor_keys_dir/keys.mk"

cat <<EOF > "$vendor_keys_dir/BUILD.bazel"
filegroup(
    name = "android_certificate_directory",
    srcs = glob([
        "*.pk8",
        "*.pem",
    ]),
    visibility = ["//visibility:public"],
)
EOF

echo "Done! Now build as usual."
echo "If builds aren't being signed, add '-include $vendor_keys_dir/keys.mk' to your device mk file."
echo "Make copies of your $vendor_keys_dir folder or upload it to a private repository as it contains your keys!"
sleep 3
