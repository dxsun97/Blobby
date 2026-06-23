cask "blobby" do
  version "1.0.0"
  sha256 ""

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
