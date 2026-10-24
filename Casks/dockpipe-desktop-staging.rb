# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.30-staging.40103059599.1.959f7ad04a7b"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.30-staging.40103059599.1.959f7ad04a7b/dockpipe-desktop_0.6.30_darwin_arm64.zip"
    sha256 "ef9a125b8078541eeb9c3ca72701c8b30222332427f84ba7e986606b847cd754"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.30-staging.40103059599.1.959f7ad04a7b/dockpipe-desktop_0.6.30_darwin_amd64.zip"
    sha256 "1d16701788ae0e10dee64f1f292995c23aee3ceca8573b13ddc13a554383ef71"
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
