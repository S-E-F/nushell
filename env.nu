# Nushell Environment Config File
#
# version = "0.84.0"

alias vim = nvim .
alias v = nvim .

def "git config list" [] {
    ^git --no-pager config --list
    | lines
    | str replace '=' '»¦«'
    | split column '»¦«' key value
    | sort-by key
}

def "git log" [--take (-n): int = 25] {
    ^git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD -n $take
    | lines
    | split column "»¦«" commit message author email date
    | upsert date {|d| $d.date | into datetime }
}

def "config all" [] {
    $env.LOCALAPPDATA 
    | path join 'nushell'
    | open
}

def "dotnet sdks" [] {
    ^dotnet --list-sdks
    | lines
    | str replace ' ' '»¦«'
    | split column '»¦«' version location
}

def pill [term: string, r: int, g: int, b: int] {
    if ($term | is-empty) {
        return ''
    } else {
        [
            (ansi -e $"38;2;($r);($g);($b)m")
            (char -u e0b6)
            (ansi reset)
            (ansi -e $"48;2;($r);($g);($b)m")
            $term
            (ansi reset)
            (ansi -e $"38;2;($r);($g);($b)m")
            (char -u e0b4)
            (ansi reset)
            
        ] | str join
    }
}

def "git branches" [] {
    do -p {
        ^git --no-optional-locks branch -v
        | lines 
        | where $it starts-with '*' 
        | str replace --regex '\*\s*' '' 
        | str replace ' ' '>|<' 
        | str replace ' ' '>|<' 
        | to text 
        | str trim 
        | split column '>|<' branch commit message 
    }
}

def "dotnet current sdk" [] {
    do -i { $env.PWD | path join 'global.json' | open | get sdk.version }
}

def "dotnet relevant" [] {
    (ls -f
    | where type == file
    | get name
    | where $it ends-with '.csproj'
         or $it ends-with '.sln'
         or $it ends-with '.props'
         or $it ends-with '.targets'
    | length) > 0
}

def pwd [] {

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    let path_color_dimmed = (if (is-admin) { ansi red_dimmed } else { ansi green_dimmed })
  [$path_color,(pwd | str trim -c (char path_sep) | split row (char path_sep) | str join $"/")] | str join | str replace --all "/" $"($path_color_dimmed)/(ansi reset)($path_color)"
}
def create_left_prompt [] {
    mut home = ""
    try {
        if $nu.os-info.name == "windows" {
            $home = $env.USERPROFILE
        } else {
            $home = $env.HOME
        }
    }

    let dir = [($env.PWD | str substring 0..($home | str length) | str replace $home "~"),($env.PWD | str substring ($home | str length)..)] | str join | split row (char path_sep) | where not ($it | is-empty)

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    
    $" ($path_color)($dir | last 1 | str join | str trim -c ':')"
}

def create_right_prompt [] {
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment = ([
        (ansi reset)
        (ansi magenta)
        (date now | format date '%d-%m-%Y %r')
    ] | str join | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
        str replace --regex --all "([AP]M)" $"(ansi magenta_underline)${1}")

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
        (ansi rb)
        ($env.LAST_EXIT_CODE)
    ] | str join)
    } else { "" }

    ([$last_exit_code, (char space), $time_segment] | str join)
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { || }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| $" (char -u eb70) " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| $" (char -u eb70) " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| $" (char -u eb70) " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    # ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
    # ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

$env.EDITOR = "code --wait"

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
