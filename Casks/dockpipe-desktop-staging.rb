# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.5-staging.38149878120.1.95d3a9815b7f"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.5-staging.38149878120.1.95d3a9815b7f/dockpipe-desktop_0.6.5_darwin_arm64.zip"
    sha256 "ad817a1b0cecae587e89aa809f05053253f6e562c8323489b1fb2054e9eb16fc"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.5-staging.38149878120.1.95d3a9815b7f/dockpipe-desktop_0.6.5_darwin_amd64.zip"
    sha256 "e37723617245ebd2109c8e392a47f4880b20ca01aa2d85b3c93e74e46ae079a0"
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
