# pure-jj is maintained as a standalone project under ~/.projects/pure-jj.
# Wire its functions into fish without copying them into this dotfiles repo.
set --query pure_jj_plugin_dir; or set --global pure_jj_plugin_dir $HOME/.projects/pure-jj
set --local plugin_dir $pure_jj_plugin_dir

if test -r $plugin_dir/conf.d/pure_jj.fish
    contains -- $plugin_dir/functions $fish_function_path
    or set --global --prepend fish_function_path $plugin_dir/functions
    source $plugin_dir/conf.d/pure_jj.fish
end
