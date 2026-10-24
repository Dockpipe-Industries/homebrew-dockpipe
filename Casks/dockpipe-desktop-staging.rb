# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.27-staging.40073665122.1.eeaea96dcf47"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.27-staging.40073665122.1.eeaea96dcf47/dockpipe-desktop_0.6.27_darwin_arm64.zip"
    sha256 "ddb0c40ce7f158e1b743e65317fb1d06f69096b67bc11a51d0addca7fd53b450"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.27-staging.40073665122.1.eeaea96dcf47/dockpipe-desktop_0.6.27_darwin_amd64.zip"
    sha256 "df943d7461a3bb1935c5a9a4fa36cc2e88bbc31732e510cbe29d2add407daca0"
  end

  name "Dockpipe Desktop (staging)"
  desc "Desktop launcher and command-line runtime for Dockpipe workflows"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"

  depends_on macos: ">= :ventura"
  depends_on formula: "dockpipe-industries/dockpipe/dockpipe-staging"

  app "DockPipe.app"

  caveats <<~EOS
    This is a staging candidate. Open Dockpipe from Applications.
    The dockpipe command is provided by the dockpipe-staging formula.
    Use this cask or the direct DMG installer, not both.
    Unsigned staging builds have not passed Apple's notarization checks.
  EOS
end
