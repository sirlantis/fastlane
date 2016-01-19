module Fastlane
  module Actions
    module SharedValues
      XCODE_INSTALL_XCODE_PATH = :XCODE_INSTALL_XCODE_PATH
    end

    class XcodeInstallAction < Action
      REQUIRED_VERSION = '~> 1.0.1'

      def self.install_command
        "gem install xcode-install -v '#{REQUIRED_VERSION}'"
      end

      def self.require_xcode_install
        require 'xcode/install'
      rescue LoadError
        Helper.log.fatal '##############################################'
        Helper.log.fatal '# Because of a dependency conflict you have to'
        Helper.log.fatal '# install the xcode-install gem manually.'
        Helper.log.fatal '# Run gem install xcode-install to install it'
        Helper.log.fatal '##############################################'
        raise "Run \"#{install_command}\" and start fastlane again"
      end

      def self.require_xcode_install_and_verify_version!
        require_xcode_install
        version = XcodeInstall::VERSION

        if version.start_with?('0') || version == '1.0.0'
          Helper.log.fatal 'Requires xcode-install with version #{REQUIRED_VERSION}'
          raise "Run \"#{install_command}\" and start fastlane again"
        end
      end

      def self.run(params)
        ENV["XCODE_INSTALL_USER"] = params[:username]
        ENV["XCODE_INSTALL_TEAM_ID"] = params[:team_id]

        require_xcode_install_and_verify_version!
        installer = XcodeInstall::Installer.new

        if installer.installed?(params[:version])
          Helper.log.info "Xcode #{params[:version]} is already installed ✨".green
        else
          installer.install_version(params[:version], true, true, true, true)
        end

        xcode = installer.installed_versions.find { |x| x.version == params[:version] }
        raise "Could not find Xcode with version '#{params[:version]}'" unless xcode
        Helper.log.info "Using Xcode #{params[:version]} on path '#{xcode.path}'"
        xcode.approve_license

        ENV["DEVELOPER_DIR"] = File.join(xcode.path, "/Contents/Developer")
        Actions.lane_context[SharedValues::XCODE_INSTALL_XCODE_PATH] = xcode.path
        return xcode.path
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Make sure a certain version of Xcode is installed"
      end

      def self.details
      end

      def self.available_options
        user = CredentialsManager::AppfileConfig.try_fetch_value(:apple_dev_portal_id)
        user ||= CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)

        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "FL_XCODE_VERSION",
                                       description: "The version number of the version of Xcode to install",
                                       verify_block: proc do |value|
                                       end),
          FastlaneCore::ConfigItem.new(key: :username,
                                       short_option: "-u",
                                       env_name: "XCODE_INSTALL_USER",
                                       description: "Your Apple ID Username",
                                       default_value: user),
          FastlaneCore::ConfigItem.new(key: :team_id,
                                       short_option: "-b",
                                       env_name: "XCODE_INSTALL_TEAM_ID",
                                       description: "The ID of your team if you're in multiple teams",
                                       optional: true,
                                       default_value: CredentialsManager::AppfileConfig.try_fetch_value(:team_id))
        ]
      end

      def self.output
        [
          ['XCODE_INSTALL_CUSTOM_VALUE', 'A description of what this value contains']
        ]
      end

      def self.return_value
        "The path to the newly installed Xcode version"
      end

      def self.authors
        ["Krausefx"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
