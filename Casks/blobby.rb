cask "blobby" do
  version "1.0.0"
  sha256 "1d18a4ab34d0ff4ac1ddc024c35b17837e4e6a7f3a7fd556e09ee6609b0712e4"

  url "https://github.com/dxsun97/Blobby/releases/download/v#{version}/Blobby-#{version}-universal.dmg"
  name "Blobby"
  desc "Animated blob cursor overlay for macOS"
  homepage "https://github.com/dxsun97/Blobby"

  depends_on macos: ">= :sonoma"

  app "Blobby.app"

  uninstall quit: "com.blobby.app"

  zap trash: [
    "~/Library/Preferences/com.blobby.app.plist",
  ]
end
