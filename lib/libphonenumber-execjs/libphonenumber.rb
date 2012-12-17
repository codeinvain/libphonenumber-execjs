class Libphonenumber

  attr_reader :context

  def initialize
    @context = ExecJS.compile(File.read(File.join(File.dirname(__FILE__), "..", "..", "support", "libphonenumber.js")))
  end

  def extractPossibleNumber(str="")
    context.call "i18n.phonenumbers.PhoneNumberUtil.extractPossibleNumber",str
  end

  def normalize(str="")
    context.call "i18n.phonenumbers.PhoneNumberUtil.normalize",str
  end

  def parse(str="", default_region="")
    context.eval "i18n.phonenumbers.PhoneNumberUtil.getInstance().parse(#{make_param(str)},#{make_param(default_region)})"
  end

  def parse_raw(str="", default_region="")
    context.eval "i18n.phonenumbers.PhoneNumberUtil.getInstance().parseAndKeepRawInput(#{make_param(str)},#{make_param(default_region)})"
  end

  def full_details(str="",default_region="",default_carrier="")
    full_details =<<-CLOSURE
      (function(num,region,carier){
        region = ( region==null ) ? '' : region;
        carier = ( carier==null ) ? '' : carier;
        var out  = {};
        var util = i18n.phonenumbers.PhoneNumberUtil.getInstance();
        num = util.parseAndKeepRawInput(num,region);
        for (var ix in num.values_) { 
          out[num.fields_[ix].name_] = num.values_[ix];
        }
        out.is_valid_number = util.isValidNumber(num);
        out.is_valid_number_for_region = util.isValidNumberForRegion(num,region);
        out.region = util.getRegionCodeForNumber(num);
        out.is_possible_number = util.isPossibleNumber(num);
        out.line_type = util.getNumberType(num);
        out.national_format= util.format(num, i18n.phonenumbers.PhoneNumberFormat.NATIONAL);
        out.line_name = (function(code){for (var attr in i18n.phonenumbers.PhoneNumberType){ if (i18n.phonenumbers.PhoneNumberType[attr]== code) return attr; }}).call(this,out.line_type);
        return out;
      }).call(this,#{make_param(str)},#{make_param(default_region)},#{make_param(default_carrier)})
CLOSURE
    context.eval full_details
  end

  def simple
    @simple ||= Simple.new(self)
  end

  def make_param(str)
    "'#{str.gsub(/[']/, '\\\\\'')}'"
  end
  class Simple

    def initialize(libphonenumber)
      @libphonenumber = libphonenumber
      @context = @libphonenumber.context
    end

    def get_e164_phone_number(str, cc=nil, ndc=nil)
      @context.call "getE164PhoneNumber", str, cc, ndc
    end

    def get_e164_with_region(str, cc=nil, ndc=nil)
      result = {}
      phone_with_meta = @context.call "getE164PhoneNumberWithMeta", str, cc, ndc
      phone_with_meta = ["",""] if phone_with_meta.empty?
      result[:e164] = phone_with_meta[0]
      result[:region] = @context.eval "i18n.phonenumbers.PhoneNumberUtil.getInstance().getRegionCodeForCountryCode(#{make_param(phone_with_meta[1])})"
      result[:region].downcase! unless result[:region].nil?
      result
    end

    def get_e164_phone_number_with_meta(str, cc=nil, ndc=nil)
      @context.call "getE164PhoneNumberWithMeta", str, cc, ndc
    end

    def make_param(str)
      "'#{str.gsub(/[']/, '\\\\\'')}'"
    end

  end

end
