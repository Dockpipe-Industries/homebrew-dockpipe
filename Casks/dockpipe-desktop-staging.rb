# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.12-staging.38347837443.1.06f33036ad16"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.12-staging.38347837443.1.06f33036ad16/dockpipe-desktop_0.6.12_darwin_arm64.zip"
    sha256 "0cd4b97fc8890da872ec5098e7a7e2a48c7d9815d29231375fbb149481238cec"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.12-staging.38347837443.1.06f33036ad16/dockpipe-desktop_0.6.12_darwin_amd64.zip"
    sha256 "2fa6cbfff198a1116252b831457a22c476bba2f7680d1c9ebcf4fab89eb96d38"
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
