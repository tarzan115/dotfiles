# Kotlin dev shell definition. Lives here so dotfiles stays the single
# source of truth; workspace flakes import it via a path input, so edits
# to this file take effect on the next `nix develop` run.
{ pkgs }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Kotlin
    kotlin

    # JDK (required for Kotlin/JVM)
    jdk

    # IntelliJ IDEA
    jetbrains.idea

    # Build tools
    gradle

    # Useful utilities
    git
    curl
    nushell
  ];

  # nix develop always launches bashInteractive and runs this hook there;
  # exec nu hands off to nushell once the environment is set up.
  shellHook = ''
    echo "Kotlin development environment loaded"
    echo "Kotlin: $(kotlinc -version 2>&1)"
    echo "Java: $(java -version 2>&1 | head -n 1)"
    echo ""
    echo "To launch IntelliJ IDEA, run: idea"
    echo "For Gradle projects, use: gradle <task>"
    exec nu
  '';
}