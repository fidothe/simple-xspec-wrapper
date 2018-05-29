require 'pathname'
require 'saxon/xml'
require 'saxon/xslt'

module XSpec
  XSPEC_DIR = Pathname.new(__dir__).join('../vendor/xspec-1.0.0')
  XSPEC_CLASSPATH_ADDITION = XSPEC_DIR.join('java')

  class Compiler
    def processor
      @processor ||= SaxonProcessorFactory.processor
    end

    def compile(xspec_path)
      xspec_path = Pathname.new(xspec_path)
      begin
        SpecFile.new(processor, xspec_path, transformer(xspec_path))
      rescue Exception => e
        BrokenSpecFile.new(xspec_path, e.to_s)
      end
    end

    def transformer(xspec_path)
      Saxon::XSLT::Stylesheet.new(compiled_xml(xspec_path))
    end

    def compiled_xml(xspec_path)
      compiler.transform(processor.XML(xspec_path.open('r:utf-8')))
    end

    private

    def compiler_path
      @compiler_path ||= XSPEC_DIR.join('src/compiler/generate-xspec-tests.xsl')
    end

    def compiler
      @compiler ||= processor.XSLT(compiler_path.open('r:utf-8'))
    end
  end

  class Suite
    attr_reader :compiler, :path

    def initialize(compiler, path)
      @compiler, @path = compiler, Pathname.new(path).realpath
    end

    def spec_files
      @spec_files ||= Pathname.glob(path.join('**/*.xspec').to_s).map { |spec_path| compiler.compile(spec_path.realpath) }.compact
    end

    def run!
      unless successful.empty?
        puts "SUCCESSFUL:"
        successful.each do |spec_file|
          puts "+ #{simple_path(spec_file)}"
        end
      end
      unless errors.empty?
        puts "ERRORED:"
        errors.each do |spec_file|
          puts "+ #{simple_path(spec_file)}"
          puts "    #{spec_file.error.split("\n").join("\n    ")}"
        end
      end
      unless failures.empty?
        puts "FAILURES:"
        failures.each do |spec_file|
          puts "+ #{simple_path(spec_file)}"
          spec_file.failures.each do |failure|
            puts "  - #{failure}"
          end
        end
      end
      errors.empty? && failures.empty?
    end

    def failures_or_errors?
     !clean?
    end

    def clean?
      failures.empty? && errors.empty?
    end

    private

    def simple_path(spec_file)
      spec_file.path.relative_path_from(Pathname.pwd)
    end

    def ensure_ran!
      spec_files.each do |spec_file|
        spec_file.run!
      end
    end

    def failures
      @failures ||= begin
        ensure_ran!
        spec_files.select { |spec_file| spec_file.failures? }
      end
    end

    def errors
      @errors ||= begin
        ensure_ran!
        spec_files.select { |spec_file| spec_file.errored? }
      end
    end

    def successful
      @successful ||= begin
        ensure_ran!
        spec_files.select { |spec_file| spec_file.successful? }
      end
    end
  end

  class BrokenSpecFile
    attr_reader :path, :error, :failures

    def initialize(path, error)
      @path, @error = path, error
      @failures = [].freeze
    end

    def ran?
      true
    end

    def not_run?
      false
    end

    def errored?
      true
    end

    def failures?
      false
    end

    def successful?
      false
    end

    def run!
    end
  end

  class SpecFile
    attr_reader :processor, :path, :compiled_xspec, :failures, :error

    def initialize(processor, path, compiled_xspec)
      @processor, @path, @compiled_xspec = processor, path, compiled_xspec
      @ran = false
      @errored = false
      @failures = []
      @error = ''
    end

    def not_run?
      !@ran
    end

    def ran?
      @ran
    end

    def failures?
      !@failures.empty?
    end

    def errored?
      @errored
    end

    def successful?
      !(failures? || errored?)
    end

    def run!
      if not_run?
        begin
          @ran = true
          output = compiled_xspec.transform_with_named_template(Saxon::S9API::QName.fromClarkName('{http://www.jenitennison.com/xslt/xspec}main'))
          check_failures(output).each do |failure|
            @failures << test_label(failure)
          end
        rescue Exception => e
          @errored = true
          @error = e.to_s
        end
      end
    end

    private

    def check_failures(output)
      output.xpath("//x:test[@successful = 'false']", 'x' => 'http://www.jenitennison.com/xslt/xspec').map { |failure|
        Saxon::XML::Document.new(failure, processor)
      }
    end

    def test_label(failure_node)
      failure_node.xpath('ancestor-or-self::x:*[x:label]', 'x' => 'http://www.jenitennison.com/xslt/xspec').map { |label_parent|
        Saxon::XML::Document.new(label_parent, processor).xpath('x:label/text()', 'x' => 'http://www.jenitennison.com/xslt/xspec').map { |label_node| label_node.to_s.strip }
      }.reverse.join(' ')
    end
  end
end

class SaxonProcessorFactory
  def self.processor
    new.processor
  end

  def saxon_conf
    license_file_path = Pathname.pwd.join('saxon-license.lic')
    if license_file_path.file?
      Saxon::Loader.load!(ENV['SAXON_HOME'] || '/opt/saxon')
      Saxon::Configuration.create_licensed(license_file_path.to_s)
    else
      nil
    end
  end

  def processor
    Saxon::Processor.create(saxon_conf)
  end
end

class Saxon::XSLT::Stylesheet
  def xslt_transformer
    ct = Thread.current
    thread_instance_var_key = :"xslt_transformer_#{object_id}"
    return ct.thread_variable_get(thread_instance_var_key) if ct.thread_variable?(thread_instance_var_key)
    ct.thread_variable_set(thread_instance_var_key, @xslt.load)
  end

  def setup_and_run(document, params, output, transformer)
    transformer.setInitialContextNode(document.to_java)
    transformer.setDestination(output)
    set_params(transformer, document, params)
    transformer.transform
  end

  def transform(document, params = {})
    output = Saxon::S9API::XdmDestination.new
    setup_and_run(document, params, output, xslt_transformer)
    doc = Saxon::XML::Document.new(output.getXdmNode, processor)
    output.close
    doc
  end

  def setup_and_run_template(template_qname, params, output, transformer)
    transformer.setInitialTemplate(template_qname)
    transformer.setDestination(output)
    params_document = Saxon::XML('<empty/>')
    set_params(transformer, params_document, params)
    transformer.transform
  end

  def transform_with_named_template(template_qname, params = {})
    output = Saxon::S9API::XdmDestination.new
    setup_and_run_template(template_qname, params, output, xslt_transformer)
    doc = Saxon::XML::Document.new(output.getXdmNode, processor)
    output.close
    doc
  end
end

class Saxon::XML::Document
  def xpath(expr, ns = {})
    compiler = processor.to_java.new_xpath_compiler
    ns.each do |prefix, url|
      compiler.declareNamespace(prefix, url)
    end
    compiler.evaluate(expr, @xdm_document)
  end
end

$CLASSPATH << XSpec::XSPEC_CLASSPATH_ADDITION.to_s
