# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.15-staging.38500140985.1.9cfcdcbb5441"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.15-staging.38500140985.1.9cfcdcbb5441/dockpipe-desktop_0.6.15_darwin_arm64.zip"
    sha256 "51db5cf3ce80d4608f5fa9ec96ee12f630a5f3f22392fa21f2d974da0ee96ca1"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.15-staging.38500140985.1.9cfcdcbb5441/dockpipe-desktop_0.6.15_darwin_amd64.zip"
    sha256 "a68d4f7c6b76caf1dd4d1533fa363746aa28dfbbf7a3c5be00cbca6a484582fb"
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
