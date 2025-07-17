
set ENV_HOME ~/python-virtualenv
set PROJECT_HOME ~/Workspace
set ACTIVATE_FISH bin/activate.fish

function act
    set PROJECT $argv[1]
    set ENV_TO_SOURCE $ENV_HOME/$PROJECT/$ACTIVATE_FISH
    if test -f $ENV_TO_SOURCE
        echo "Sourcing $PROJECT"
        source $ENV_TO_SOURCE
    else
        echo "No python env to activate for $PROJECT"
    end

    if test -d $PROJECT_HOME/$PROJECT
        echo "Changing dir to $PROJECT"
        cd $PROJECT_HOME/$PROJECT
    else
        echo "No project named as $PROJECT exists"
    end
end

