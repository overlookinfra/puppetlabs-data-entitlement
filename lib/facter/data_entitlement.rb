# Get information about HDP
require 'facter'
require 'puppet'
require 'json'

## Add a custom fact that scrapes the current health of the HDP app stack
## Also grab the current owner the puppet certs and keys
Facter.add(:data_entitlement_health) do
  confine kernel: 'Linux'
  out = {}
  setcode do
    if Dir.exist?('/opt/puppetlabs/data_entitlement')
      begin
        image_data = {}
        cmd_output = Facter::Core::Execution.execute("docker ps --all --no-trunc --format '{{ json . }}'").split("\n")
        containers = []
        cmd_output.each do |json_hash|
          data = JSON.parse(json_hash)
          containers.push(data)
        end

        containers.each do |container|
          key = container['Names']
          value = {}
          next unless key.start_with?('data_entitlement_')
          value['image'] = container['Image'].split(':')[0]
          value['tag'] = container['Image'].split(':')[1]
          data = Facter::Core::Execution.execute("docker inspect --format '{{ json .Image }}' #{key}")
          value['sha'] = JSON.parse(data).split(':')[1]
          image_data[key.to_s] = value
        end

        out['image_data'] = image_data
      rescue # rubocop:disable Lint/SuppressedException
      end
    end

    out['puppet_user'] = Facter::Core::Execution.execute("bash -c \"stat -c '%G' /etc/puppetlabs/puppet/ssl/private_keys/#{Facter.value('fqdn')}.pem | xargs id -u\"").to_i
    out
  end
end
