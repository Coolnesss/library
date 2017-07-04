module LanguageHelper
  def self.languages
    (LanguageList::COMMON_LANGUAGES.map(&:name) + ["Sindhi"]).sort
  end
end
