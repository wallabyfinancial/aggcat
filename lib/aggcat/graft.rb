module Aggcat
  class Graft < Aggcat::Client

    BASE_URL = 'https://financialdatafeed.platform.intuit.com/v1'

    def graft(account_ids)
      post('/graft/accounts', graft_accounts(account_ids))
    end
    
    private
    
    def graft_accounts(account_ids)
      xml = Builder::XmlMarkup.new
      xml.GraftAccounts('xmlns' => GRAFT_NAMESPACE) do |graft_account|
        account_ids.each do |account_id|
          graft_account.graftAccountId(account_id)
        end
      end
    end
    
  end
end