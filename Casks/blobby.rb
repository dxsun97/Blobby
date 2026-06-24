cask "blobby" do
  version "1.0.1"
  sha256 "3c7b80f45d20bd02864f670db3c6eab756a4916a30a9b2a3b424228e60c9c81d"

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
