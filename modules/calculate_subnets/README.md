# How are subnet cidrs calculated

Below are examples for /16 and /20 vpc.  We use `*` to mark the VPC size and
`|` for subnets.

## Example of subnets in a /16 vpc

Assuming the vpc cidr is `10.1.0.0/16`.  The following are the computed subnet cidrs:

### pas_cidr

```
cidrsubnet(var.vpc_cidr, local.newbits_to_large, 1) =
  cidrsubnet("10.1.0.0/16", 6, 1) =

  0000 1010.0000 0001 .* 0000 00 | 00. 0000 0000 or'd with
  0000 0000.0000 0000 .* 0000 01 | 00. 0000 0000 =

  0000 1010.0000 0001 .* 0000 01 | 00. 0000 0000 =

  "10.1.4.0/22"
```

### services_cidr


```
cidrsubnet(var.vpc_cidr, local.newbits_to_large, 2) =
  cidrsubnet("10.1.0.0/16", 6, 2) =

  0000 1010.0000 0001 .* 0000 00 | 00. 0000 0000 or'd with
  0000 0000.0000 0000 .* 0000 10 | 00. 0000 0000 =

  0000 1010.0000 0001 .* 0000 10 | 00. 0000 0000 =

  "10.1.8.0/22"
```

### rds_cidr


```
cidrsubnet(var.vpc_cidr, local.newbits_to_large, 3) =
  cidrsubnet("10.1.0.0/16", 6, 3) =

  0000 1010.0000 0001 .* 0000 00 | 00. 0000 0000 or'd with
  0000 0000.0000 0000 .* 0000 11 | 00. 0000 0000 =

  0000 1010.0000 0001 .* 0000 11 | 00. 0000 0000 =

  "10.1.12.0/22"
```

### portal_cidr


```
cidrsubnet(var.vpc_cidr, local.newbits_to_large, 4) =
  cidrsubnet("10.1.0.0/16", 6, 4) =

  0000 1010.0000 0001 .* 0000 00 | 00. 0000 0000 or'd with
  0000 0000.0000 0000 .* 0001 00 | 00. 0000 0000 =

  0000 1010.0000 0001 .* 0001 00 | 00. 0000 0000 =

  "10.1.16.0/22"
```

The range of this subnet is `10.1.16.0-10.1.19.255`

### infrastructure_cidr


```
cidrsubnet(var.vpc_cidr, local.newbits_to_large, 1) =
  cidrsubnet("10.1.0.0/16", 10, 80) =

  0000 1010.0000 0001 .* 0000 0000. 00 | 00 0000 or'd with
  0000 0000.0000 0000 .* 0001 0100. 00 | 00 0000 =

  0000 1010.0000 0001 .* 0001 0100. 00 | 00 0000 =

  "10.1.20.0/26"
```

The range of this subnet is `10.1.20.0-10.1.20.255`

## Example of subnets in a /20 vpc

Assuming the vpc cidr is `10.1.0.0/20`.  The following are the computed subnet cidrs:

### pas_cidr

```
cidrsubnet(var.vpc_cidr, local.newbits_to_large, 1) =
  cidrsubnet("10.1.0.0/20", 3, 1) =

  0000 1010.0000 0001.0000 * 000 | 0. 0000 0000 or'd with
  0000 0000.0000 0000.0000 * 001 | 0. 0000 0000 =

  0000 1010.0000 0001.0000 * 001 | 0. 0000 0000 =
  "10.1.2.0/23"
```

### services_cidr

```
  cidrsubnet("10.1.0.0/20", 3, 2) =

  0000 1010.0000 0001.0000 * 000 | 0. 0000 0000 or'd with
  0000 0000.0000 0000.0000 * 010 | 0. 0000 0000 =

  0000 1010.0000 0001.0000 * 010 | 0. 0000 0000 =
  "10.1.4.0/23"
```

### rds_cidr

```
  cidrsubnet("10.1.0.0/20", 3, 3) =

  0000 1010.0000 0001.0000 * 000 | 0. 0000 0000 or'd with
  0000 0000.0000 0000.0000 * 011 | 0. 0000 0000 =

  0000 1010.0000 0001.0000 * 011 | 0. 0000 0000 =
  "10.1.6.0/23"
```

### portal_cidr

```
  cidrsubnet("10.1.0.0/20", 3, 4) =

  0000 1010.0000 0001.0000 * 000 | 0. 0000 0000 or'd with
  0000 0000.0000 0000.0000 * 100 | 0. 0000 0000 =

  0000 1010.0000 0001.0000 * 100 | 0. 0000 0000 =
  "10.1.8.0/23"
```

The range of this subnet is `10.1.8.0-10.1.9.255`

### infrastructure_cidr

```
  cidrsubnet("10.1.0.0/20", 6, 40) =

  0000 1010.0000 0001.0000 * 0000. 00 | 00 0000 or'd with
  0000 0000.0000 0000.0000 * 1010. 00 | 00 0000 =

  0000 1010.0000 0001.0000 * 1010. 00 | 00 0000 =
  "10.1.10.0/26"
```

The range of this subnet is `10.1.10.0-10.1.10.63`
