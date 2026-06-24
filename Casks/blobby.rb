cask "blobby" do
  version "1.0.2-beta.1"
  sha256 "99df1433430df3692c444cf1a88051bbace23fcf1ee4b87acf7532f3f36db490"

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
