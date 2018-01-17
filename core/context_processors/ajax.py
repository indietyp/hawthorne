def ajax_processor(request):
  return {'ajax': True if request.method == 'POST' else False}
