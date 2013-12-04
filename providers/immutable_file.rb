
def initizlize(*args)
    super
    @action = :create
    @owner = "root"
    @group = "root"
    @mode = 0755
end

action :create do

    file "#{new_resource.file_name}" do
        mode new_resource.mode
        owner "#{new_resource.owner}" if new_resource.owner
        group "#{new_resource.group}" if new_resource.group
        content new_resource.content if new_resource.content
        action :create_if_missing
    end

    execute "change permissions on #{new_resource.file_name}" do
        command "chattr +i #{new_resource.file_name}"
        action :run
    end
end

