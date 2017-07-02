FactoryGirl.define do
  factory :user do
    name "John"
    password  "Doe"
    password_confirmation "Doe"
  end

  factory :book do
    name "Philosophiæ Naturalis Principia Mathematica"
    name_eng "Mathematical Principles of Natural Philosophy"
    author "Isaac Newton"
    year 1686
    description_sindhi "The famous book of Mathematical Principles of Natural Philosophy marked the epoch of a great revolution in physics. The method followed by its illustrious author Sir Newton ... spread the light of mathematics on a science which up to then had remained in the darkness of conjectures and hypotheses."
    description_eng "The famous book of Mathematical Principles of Natural Philosophy marked the epoch of a great revolution in physics. The method followed by its illustrious author Sir Newton ... spread the light of mathematics on a science which up to then had remained in the darkness of conjectures and hypotheses."
    publisher "Halley"
  end
end