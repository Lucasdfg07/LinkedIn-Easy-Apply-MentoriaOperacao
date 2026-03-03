# frozen_string_literal: true

module EasyApply
  module Matching
    class RequirementExtractor
      # ~200 tech terms with aliases
      SKILL_ALIASES = {
        'ruby' => %w[ruby rb],
        'rails' => %w[rails ror ruby\ on\ rails rubyonrails],
        'javascript' => %w[javascript js ecmascript],
        'typescript' => %w[typescript ts],
        'python' => %w[python py python3],
        'java' => %w[java jdk jre],
        'csharp' => %w[c# csharp .net dotnet],
        'cpp' => %w[c++ cpp],
        'go' => %w[golang go],
        'rust' => %w[rust rustlang],
        'php' => %w[php laravel symfony],
        'swift' => %w[swift ios],
        'kotlin' => %w[kotlin android],
        'react' => %w[react reactjs react.js],
        'angular' => %w[angular angularjs angular.js],
        'vue' => %w[vue vuejs vue.js],
        'svelte' => %w[svelte sveltekit],
        'nextjs' => %w[next.js nextjs next],
        'nodejs' => %w[node.js nodejs node],
        'express' => %w[express expressjs],
        'django' => %w[django],
        'flask' => %w[flask],
        'spring' => %w[spring spring\ boot springboot],
        'postgresql' => %w[postgresql postgres psql],
        'mysql' => %w[mysql mariadb],
        'mongodb' => %w[mongodb mongo],
        'redis' => %w[redis],
        'elasticsearch' => %w[elasticsearch elastic],
        'dynamodb' => %w[dynamodb dynamo],
        'sqlite' => %w[sqlite],
        'sql' => %w[sql],
        'graphql' => %w[graphql gql],
        'rest_api' => %w[rest restful rest\ api api],
        'grpc' => %w[grpc protobuf],
        'docker' => %w[docker container containerization],
        'kubernetes' => %w[kubernetes k8s],
        'terraform' => %w[terraform iac],
        'ansible' => %w[ansible],
        'aws' => %w[aws amazon\ web\ services],
        'gcp' => %w[gcp google\ cloud],
        'azure' => %w[azure microsoft\ azure],
        'heroku' => %w[heroku],
        'vercel' => %w[vercel],
        'git' => %w[git github gitlab bitbucket],
        'ci_cd' => %w[ci/cd ci cd jenkins github\ actions circleci],
        'linux' => %w[linux unix ubuntu debian centos],
        'nginx' => %w[nginx],
        'apache' => %w[apache httpd],
        'html' => %w[html html5],
        'css' => %w[css css3 scss sass less tailwind],
        'tailwind' => %w[tailwindcss tailwind],
        'bootstrap' => %w[bootstrap],
        'webpack' => %w[webpack],
        'vite' => %w[vite],
        'jest' => %w[jest],
        'rspec' => %w[rspec],
        'pytest' => %w[pytest],
        'selenium' => %w[selenium webdriver],
        'cypress' => %w[cypress],
        'playwright' => %w[playwright],
        'agile' => %w[agile scrum kanban],
        'tdd' => %w[tdd test\ driven],
        'bdd' => %w[bdd behavior\ driven],
        'microservices' => %w[microservices micro\ services],
        'serverless' => %w[serverless lambda],
        'rabbitmq' => %w[rabbitmq amqp],
        'kafka' => %w[kafka],
        'sidekiq' => %w[sidekiq],
        'celery' => %w[celery],
        'redux' => %w[redux],
        'mobx' => %w[mobx],
        'sass' => %w[sass scss],
        'jquery' => %w[jquery],
        'figma' => %w[figma],
        'jira' => %w[jira],
        'confluence' => %w[confluence],
        'datadog' => %w[datadog],
        'splunk' => %w[splunk],
        'grafana' => %w[grafana prometheus],
        'oauth' => %w[oauth oauth2 openid],
        'jwt' => %w[jwt json\ web\ token],
        'websocket' => %w[websocket ws socket.io],
        'machine_learning' => %w[machine\ learning ml ai artificial\ intelligence],
        'tensorflow' => %w[tensorflow tf],
        'pytorch' => %w[pytorch torch],
        'pandas' => %w[pandas numpy],
        'spark' => %w[spark apache\ spark pyspark],
        'hadoop' => %w[hadoop hdfs],
        'snowflake' => %w[snowflake],
        'dbt' => %w[dbt],
        'airflow' => %w[airflow],
        'tableau' => %w[tableau],
        'power_bi' => %w[power\ bi powerbi],
        'solidity' => %w[solidity blockchain web3],
        'flutter' => %w[flutter dart],
        'react_native' => %w[react\ native],
        'electron' => %w[electron],
        'unity' => %w[unity unreal],
        'supabase' => %w[supabase],
        'firebase' => %w[firebase],
        'stripe' => %w[stripe],
        'twilio' => %w[twilio],
        'sendgrid' => %w[sendgrid],
        'vault' => %w[vault hashicorp],
        'consul' => %w[consul],
      }.freeze

      EXPERIENCE_PATTERNS = [
        /(\d+)\+?\s*(?:years?|anos?|yrs?)\s*(?:of\s+)?(?:experience|experi[eê]ncia)/i,
        /(?:experience|experi[eê]ncia)\s*(?:of\s+)?(\d+)\+?\s*(?:years?|anos?|yrs?)/i,
        /(\d+)\+?\s*(?:years?|anos?)\s*(?:working|developing|programming)/i,
        /minimum\s*(?:of\s+)?(\d+)\s*(?:years?|anos?)/i,
        /at\s+least\s+(\d+)\s*(?:years?|anos?)/i,
      ].freeze

      EDUCATION_LEVELS = {
        'phd' => %w[phd ph.d doctorate doctoral doutorado],
        'master' => %w[master masters msc m.s mestrado],
        'bachelor' => %w[bachelor bachelors bsc b.s degree bacharelado gradua],
        'associate' => %w[associate associates tecnólogo],
        'high_school' => %w[high\ school ensino\ médio],
      }.freeze

      EDUCATION_HIERARCHY = %w[high_school associate bachelor master phd].freeze

      def extract(description)
        text = description.to_s.downcase

        {
          skills: extract_skills(text),
          years_required: extract_years(text),
          education_required: extract_education(text)
        }
      end

      private

      def extract_skills(text)
        found = Set.new

        SKILL_ALIASES.each do |canonical, aliases|
          aliases.each do |term|
            if text.include?(term)
              found << canonical
              break
            end
          end
        end

        found.to_a
      end

      def extract_years(text)
        EXPERIENCE_PATTERNS.each do |pattern|
          match = text.match(pattern)
          return match[1].to_i if match
        end
        nil
      end

      def extract_education(text)
        EDUCATION_LEVELS.each do |level, terms|
          return level if terms.any? { |t| text.include?(t) }
        end
        nil
      end
    end
  end
end
