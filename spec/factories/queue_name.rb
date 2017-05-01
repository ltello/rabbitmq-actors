FactoryGirl.define do
  sequence(:queue_name, "queue_created_at_#{'%10.10f' % Time.current.to_f}")
end
