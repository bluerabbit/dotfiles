# require ruby
# gem install rqrcode
# gem install chunky_png
# qrcode "https://example.com"
function qrcode() {
  QRCODE_URL=$1 ruby -r rqrcode -e 'IO.binwrite("/tmp/qrcode.png", RQRCode::QRCode.new(ENV["QRCODE_URL"]).as_png.to_s)'
  open /tmp/qrcode.png
}
