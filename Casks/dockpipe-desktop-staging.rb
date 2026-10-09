# Generated from a completed staging release; update through the sync workflow.
cask "dockpipe-desktop-staging" do
  version "0.6.3-staging.37959504785.1.4da6948415b9"

  on_arm do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.3-staging.37959504785.1.4da6948415b9/dockpipe-desktop_0.6.3_darwin_arm64.zip"
    sha256 "457319015dfc43cf2bda62806420df8d81a7c5b8245e038f95bfef53424e786c"
  end

  on_intel do
    url "https://packages.staging.dockpipe.com/packages/candidates/0.6.3-staging.37959504785.1.4da6948415b9/dockpipe-desktop_0.6.3_darwin_amd64.zip"
    sha256 "f8d1b57d8392139271e93033466cdad4cadbf832495da456a99b1a14b055e78e"
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
