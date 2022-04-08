product-name: pws-dark-runtime-config-tile
product-properties:
  .properties.ssh_banner:
    value: |
      ${indent(6, ssh_banner)}
  .properties.users_to_add:
    value: %{if length(extra_users)<1}[]%{endif}
    %{~ for user in extra_users ~}
    - name: ${user.username}
      public_key: ${user.public_ssh_key}
      sudo: ${user.sudo_priv}
    %{~ endfor ~}