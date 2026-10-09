# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.1-staging.37817108070.1.cdc7ac2f9c36"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.1-staging.37817108070.1.cdc7ac2f9c36/dockpipe-desktop_0.6.1_darwin_arm64.zip"
    sha256 "947a0a637786040222c06ce318d6adecdb6cc467ef0e1c90f3767777b7e601a7"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.1-staging.37817108070.1.cdc7ac2f9c36/dockpipe-desktop_0.6.1_darwin_amd64.zip"
    sha256 "080c18efdbd20059008b22033f632297f450c0f228bc80a8d19556536fd1678d"
  end

  name "DockPipe Desktop (staging)"
  desc "Desktop launcher and command-line runtime for DockPipe workflows"
  homepage "https://github.com/Dockpipe-Industries/dockpipe"

  depends_on macos: ">= :ventura"
  depends_on formula: "dockpipe-industries/dockpipe/dockpipe-staging"

  app "DockPipe.app"

  caveats <<~EOS
    This is a staging candidate. Open DockPipe from Applications.
    The dockpipe command is provided by the dockpipe-staging formula.
    Use this cask or the direct DMG installer, not both.
    Unsigned staging builds have not passed Apple's notarization checks.
  EOS
end
