# encoding: UTF-8

def error(err)
  if err.respond_to?(:message)
    err_mess = "#{err.message} (quitter et consulter le journal.log)"
    err_log = "ERROR: #{err.message}#{RC}#{err.backtrace.join(RC)}"
  else
    err_mess = err_log = err
  end
  CWindow.error(err_mess)
  log(err_log)
end #/ error
alias :erreur :error
