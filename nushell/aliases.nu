alias cg = cargo
alias cgi = cargo binstall -y
alias cgs = cargo search
alias cgt = cargo test
alias cgx = cargo expand
alias gg = gitui
alias icgs = cargo binstall -y
alias ll = ls -la
alias lstr = lstr --icons --color always

alias tg = topgrade -y --no-retry

# aliases as a function
def --env tk [dir] {
    mkdir $dir
    z $dir
}

def --wrapped cga [...args] {
	cargo add ...$args
	bat Cargo.toml
}

def --env cgn [project_name] {
    cargo new $project_name
    z $project_name
		hx src/main.rs
}

def cgr [] {
	cargo clippy --quiet
	cargo run --quiet 
}

def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	^yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != $env.PWD and ($cwd | path exists) {
		cd $cwd
	}
	rm -fp $tmp
}

# brew helpers (macOS only; NixOS packages are declarative via home.nix)
def brew-only [] {
    if $nu.os-info.name != "macos" {
        error make { msg: "brew helpers are macOS-only — manage packages via home.nix on NixOS" }
    }
}

def --wrapped bi [...pkgs] { brew-only; ^brew install ...$pkgs }
def --wrapped brm [...pkgs] { brew-only; ^brew uninstall ...$pkgs }
def --wrapped bs [...pkgs] { brew-only; ^brew search ...$pkgs }
def bup [] { brew-only; ^brew update; ^brew upgrade }
