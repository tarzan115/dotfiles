alias cg = cargo
alias cgi = cargo binstall -y
alias cgs = cargo search
alias cgt = cargo test
alias cgx = cargo expand
alias di = sudo dnf install -y
alias drm = sudo dnf remove -y
alias ds = dnf search
alias icgs = cargo binstall -y
alias ids = sudo dnf install -y
alias ll = ls -la
alias lstr = lstr --icons --color always
alias rr = rustrover
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
		hx
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
