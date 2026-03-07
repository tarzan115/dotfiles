alias cg = cargo
alias cgi = cargo binstall -y
alias cgs = cargo search
alias di = sudo dnf install -y
alias drm = sudo dnf remove -y
alias ds = dnf search
alias tg = topgrade -y --no-retry



# aliases as a function
def --env tk [dir] {
    mkdir $dir
    z $dir
}

def --env cgn [project_name] {
    cargo new $project_name
    zed -n $project_name
    z $project_name
}
