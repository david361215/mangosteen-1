class UserMailer < ApplicationMailer
  def welcome_email(code)
    @code = code
    mail(to: "330597761@qq.com", subject: 'hi')
  end
end
