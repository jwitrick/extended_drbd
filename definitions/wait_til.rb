

define :wait_til, :wait_interval => 60 do
    command = params[:command] ? params[:command] : "echo 'No command found'"

    ruby_block "#{params[:name]}" do
        block do
            until system("#{command}") do
                Chef::Log.info(params[:message]) if defined?(params[:message])
                sleep params[:wait_interval]
            end
        end
    end
end

define :wait_til_not, :wait_interval => 60 do
    command = params[:command] ? params[:command] : "echo 'No command found'"

    ruby_block "#{params[:name]}" do
        block do
            until system("! #{command}") do
                Chef::Log.info(params[:message]) if defined?(params[:message])
                sleep params[:wait_interval]
            end
        end
    end
end
