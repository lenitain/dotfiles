# Personal fish plugins are separate Git repositories under ~/.projects,
# declared in mise's [bootstrap.repos]. This file is the single registration
# point: it adds each plugin's functions/completions and sources its conf.d.
set --query fish_personal_plugin_dirs
or set --global fish_personal_plugin_dirs $HOME/.projects/pure-jj

for plugin_dir in $fish_personal_plugin_dirs
    if test -d $plugin_dir/functions
        contains -- $plugin_dir/functions $fish_function_path
        or set --global --prepend fish_function_path $plugin_dir/functions
    end
    if test -d $plugin_dir/completions
        contains -- $plugin_dir/completions $fish_complete_path
        or set --global --prepend fish_complete_path $plugin_dir/completions
    end
    for init in $plugin_dir/conf.d/*.fish
        test -r $init; and source $init
    end
end
