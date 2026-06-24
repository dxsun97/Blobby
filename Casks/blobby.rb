cask "blobby" do
  version "1.0.2-beta.1"
  sha256 "55f7cdc9b3003a05608d1cdee4a17ba6d32f954e296f640562c4cda5439af8ad"

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
