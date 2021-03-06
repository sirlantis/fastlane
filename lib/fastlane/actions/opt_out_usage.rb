module Fastlane
  module Actions
    class OptOutUsageAction < Action
      def self.run(params)
        ENV['FASTLANE_OPT_OUT_USAGE'] = "YES"
        Helper.log.info "Disabled upload of used actions"
      end

      def self.description
        "This will stop uploading the information which actions were run"
      end

      def self.details
        [
          "By default, fastlane will share the used actions. ",
          "No personal information is shard. More information available on ",
          "https://github.com/fastlane/enhancer\n",
          "Using this action you can opt out"
        ].join('')
      end

      def self.author
        "KrauseFx"
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
