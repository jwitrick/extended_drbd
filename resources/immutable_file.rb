
actions :create

attribute :group,   :regex => [/^([a-z]|[A-Z]|[0-9]|_|-)+$/]
attribute :owner,   :regex => [/^([a-z]|[A-Z]|[0-9]|_|-)+$/] 
attribute :mode,    :regex => /^0?\d{3,4}$/
attribute :file_name,   :kind_of => String
attribute :content,     :kind_of => String
