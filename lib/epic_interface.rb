require 'savon'
require 'securerandom'
require 'builder'

# The Savon client by default does not allow adding new soap headers
# except via the global configuration.  This monkey patch allows adding
# soap headers via local (per-message) configuration.
module Savon
  class LocalOptions < Options
    def soap_header(header)
      @options[:soap_header] = header
    end
  end

  class Header
    def header
      @header ||= build_header
    end

    def build_header
      header = {}
      header.update(@globals.include?(:soap_header) ? @globals[:soap_header] : {})
      header.update(@locals.include?(:soap_header) ? @locals[:soap_header] : {})
      return header
    end
  end
end

# Use this class to send protocols (studies/projects) along with their
# associated billing calendars to Epic via an InterConnect server.
#
# Configuration is stored in config/epic.yml.
class EpicInterface

  # Create a new EpicInterface
  def initialize(config = nil)
    @config = config || YAML.load_file(Rails.root.join('config', 'epic.yml'))[Rails.env]

    # TODO: grab these from the WSDL
    @namespace = @config['namespace'] || 'urn:ihe:qrph:rpe:2009'
    @endpoint = @config['endpoint'] 

    @root = @config['study_root']
    @client = Savon.client(
        logger: Rails.logger,
        soap_version: 2,
        pretty_print_xml: true,
        convert_request_keys_to: :none,
        namespace_identifier: 'rpe',
        namespace: @namespace,
        endpoint: @endpoint,
        # wsdl: @config['wsdl'],
        headers: {
        },
        soap_header: {
        },
        namespaces: {
          'xmlns:wsa' => 'http://www.w3.org/2005/08/addressing',
        })
  end

  # Send a study to the Epic InterConnect server.
  def send_study(study)
    soap_header = {
      'wsa:Action' => "#{@namespace}:RetrieveProtocolDefResponse",
      'wsa:MessageID' => SecureRandom.uuid,
      'wsa:To' => @endpoint,
    }

    subject_ofs = [ ]

    xml = Builder::XmlMarkup.new
    xml.protocolDef {
      xml.query(root: @root, extension: study.id)
      xml.plannedStudy(classCode: 'CLNTRL', moodCode: 'DEF') {
        xml.id(root: @root, extension: study.id)
        xml.title study.title
        xml.text study.brief_description

        study.project_roles.each do |project_role|
          xml.subjectOf(typeCode: 'SUBJ') {
            xml.studyCharacteristic(classCode: 'OBS', moodCode: 'EVN') {
              xml.code(code: project_role.role.upcase)
              xml.value('xsi:type' => 'ST', value: project_role.identity.ldap_uid)
            }
          }
        end
      }
    }

    @client.call(
        'RetrieveProtocolDefResponse',
        soap_header: soap_header,
        message: xml.target)

    # TODO: handle response from the server
  end
end

