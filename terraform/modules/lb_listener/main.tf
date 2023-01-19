resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = "${var.name}-${each.key}"
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = each.value.target_type
  deregistration_delay = each.value.deregistration_delay
  vpc_id               = data.aws_vpc.this.id

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      enabled             = health_check.value.enabled
      interval            = health_check.value.interval
      healthy_threshold   = health_check.value.healthy_threshold
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }
  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for item in local.target_group_attachments : "${item.name}-${item.attachment.target_id}" => item
  }

  target_group_arn  = aws_lb_target_group.this[each.value.name].arn
  target_id         = each.value.attachment.target_id
  port              = each.value.attachment.port
  availability_zone = each.value.attachment.availability_zone
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.port
  protocol          = var.protocol
  ssl_policy        = var.ssl_policy
  certificate_arn   = try(var.certificate_arns[0], null)

  dynamic "default_action" {
    for_each = [var.default_action]

    content {
      type             = default_action.value.type
      target_group_arn = default_action.value.target_group_name != null ? aws_lb_target_group.this[default_action.value.target_group_name].arn : default_action.value.target_group_arn

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "forward" {
        for_each = default_action.value.forward != null ? [default_action.value.forward] : []
        content {
          dynamic "target_group" {
            for_each = forward.value.target_group
            content {
              arn    = target_group.value.name != null ? aws_lb_target_group.this[target_group.value.name].arn : target_group.value.arn
              weight = target_group.value.weight
            }
          }
          dynamic "stickiness" {
            for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
            content {
              duration = stickiness.value.duration
              enabled  = stickiness.value.enabled
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? [default_action.value.redirect] : []
        content {
          status_code = redirect.value.status_code
          port        = redirect.value.port
          protocol    = redirect.value.protocol
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })

  depends_on = [
    aws_lb_target_group.this
  ]
}

resource "aws_lb_listener_rule" "this" {
  for_each = var.rules

  listener_arn = aws_lb_listener.this.arn

  dynamic "action" {
    for_each = each.value.actions

    content {
      type             = action.value.type
      target_group_arn = action.value.target_group_name != null ? aws_lb_target_group.this[action.value.target_group_name].arn : action.value.target_group_arn

      dynamic "fixed_response" {
        for_each = action.value.fixed_response != null ? [action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }

      dynamic "forward" {
        for_each = action.value.forward != null ? [action.value.forward] : []
        content {
          dynamic "target_group" {
            for_each = forward.value.target_group
            content {
              arn    = target_group.value.name != null ? aws_lb_target_group.this[target_group.value.name].arn : target_value.value.arn
              weight = target_group.value.weight
            }
          }
          dynamic "stickiness" {
            for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
            content {
              duration = stickiness.value.duration
              enabled  = stickiness.value.enabled
            }
          }
        }
      }

      dynamic "redirect" {
        for_each = action.value.redirect != null ? [action.value.redirect] : []
        content {
          status_code = redirect.value.status_code
          port        = redirect.value.port
          protocol    = redirect.value.protocol
        }
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? [condition.value.host_header] : []
        content {
          values = host_header.value.values
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })

  depends_on = [
    aws_lb_target_group.this
  ]
}

resource "aws_lb_listener_certificate" "this" {
  for_each        = toset(try(slice(var.certificate_arns, 1, length(var.certificate_arns) - 1), []))
  listener_arn    = aws_lb_listener.this.arn
  certificate_arn = each.value
}

resource "aws_route53_record" "core_vpc" {
  for_each = { for key, value in var.route53_records : key => value if value.account == "core-vpc" }
  provider = aws.core-vpc

  zone_id = each.value.zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = data.aws_lb.this.dns_name
    zone_id                = data.aws_lb.this.zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}

resource "aws_route53_record" "self" {
  for_each = { for key, value in var.route53_records : key => value if value.account == "self" }

  zone_id = each.value.zone_id
  name    = each.value.key
  type    = "A"

  alias {
    name                   = data.aws_lb.this.dns_name
    zone_id                = data.aws_lb.this.zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}